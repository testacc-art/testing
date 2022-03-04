#!/bin/bash

set -eo pipefail

DIR="$PWD/plugins"
EXIT=0

for FROM in stable dev; do
    for HOW in ui cli; do
        cd "$DIR"
        for zip in *-"$FROM".zip; do
            slug="${zip%-"$FROM".zip}"
            cd /var/www/html

            echo "::group::Installing $slug $FROM"
            wp --allow-root plugin install --activate "$DIR/$slug-$FROM.zip"
            rm -f "/var/www/html/wp-content/plugins/$slug/ci-flag.txt"
            echo "::endgroup::"

            # Update the plugin.
            echo "::group::Upgrading $slug via $HOW"
            P="$(wp --allow-root plugin path "$slug" | sed 's!^/var/www/html/wp-content/plugins/!!')"
            wp --allow-root --quiet option set fake_plugin_update_plugin "$P"
            wp --allow-root --quiet option set fake_plugin_update_url "$DIR/$slug-dev.zip"
            : > /var/www/html/wp-content/debug.log
            if [[ "$HOW" == 'cli' ]]; then
                if ! wp --allow-root plugin upgrade "$slug" 2>&1 | tee "$DIR/out.txt"; then
                    echo "::error::CLI upgrade of $slug from $FROM exited with a non-zero status"
                    EXIT=1
                fi
            else
                chown -R www-data:www-data /var/www/html
                curl -v --get --url 'http://localhost/wp-admin/update.php?action=upgrade-plugin&_wpnonce=bogus' --data "plugin=$P" --output "$DIR/out.txt" 2>&1
                cat "$DIR/out.txt"
            fi
            echo '== Debug log =='
            cat /var/www/html/wp-content/debug.log
            wp --allow-root --quiet option delete fake_plugin_update_plugin
            wp --allow-root --quiet option delete fake_plugin_update_url
            echo "::endgroup::"
            ERR="$(grep -i 'Fatal error' "$DIR/out.txt" || true)"
            if [[ -n "$ERR" ]]; then
                echo "::error::Mid-upgrade fatal detected for $slug $HOW update from $FROM!%0A$ERR"
                EXIT=1
            elif [[ ! -e "/var/www/html/wp-content/plugins/$slug/ci-flag.txt" ]]; then
                echo "::error::Plugin $slug ($HOW update from $FROM) does not seem to have been updated?"
                EXIT=1
            fi

            echo "::group::Uninstalling $slug"
            wp --allow-root plugin deactivate "$slug"
            wp --allow-root plugin uninstall "$slug"
            echo "::endgroup::"
        done
    done
done
exit $EXIT
