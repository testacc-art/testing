console.log( "ok!" );

module.exports = {
    branchPrefix: 'renovate/',
    allowPlugins: true,
    allowScripts: true,
    gitAuthor: 'Renovate Bot <bot@renovateapp.com>',
    platform: 'github',
    repositories: [
        'anomiex/testing',
    ],
    baseBranches: [ 'renovate-test' ],
    cacheDir: '/tmp/renovate-cache',

    onboarding: false,
    requireConfig: false,

    allowedPostUpgradeCommands: [ '.github/test.sh' ],
    postUpgradeTasks: {
        commands: [ '.github/test.sh' ],
        fileFilters: [ 'foo/*' ],
        executionMode: 'branch',
    },

    extends: [ 'config:base' ],
};
