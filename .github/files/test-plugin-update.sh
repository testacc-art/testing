#!/bin/bash

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
            wp --allow-root --quiet option set fake_plugin_update_url "$DIR/$slug-dev.zip"
            if [[ "$HOW" == 'cli' ]]; then
                if ! wp --allow-root plugin upgrade "$slug" 2>&1 | tee out.txt; then
                    echo "::error::CLI upgrade exited with a non-zero status"
                    EXIT=1
                fi
            else
                P="$(wp --allow-root plugin path "$slug" | sed 's!^/var/www/html/wp-content/plugins/!!')"
                curl -v --get --url 'http://localhost/wp-admin/update.php?action=upgrade-plugin&_wpnonce=bogus' --data "plugin=$P" --output out.txt 2>&1
                cat out.txt
            fi
            wp --allow-root --quiet option delete fake_plugin_update_url
            echo "::endgroup::"
            if [[ ! -e "/var/www/html/wp-content/plugins/$slug/ci-flag.txt" ]]; then
                echo "::error::Plugin does not seem to have been updated?"
                EXIT=1
            else
                ERR="$(grep 'Fatal error' out.txt || true)"
                if [[ -n "$ERR" ]]; then
                    echo "::error::Mid-upgrade fatal detected!%0A$ERR"
                fi
            fi

            echo "::group::Uninstalling $slug"
            wp --allow-root plugin deactivate "$slug"
            wp --allow-root plugin uninstall "$slug"
            echo "::endgroup::"
        done
    done
done
exit $EXIT
