pipeline {
    agent any
    environment {
        PATH = "$PATH:/home/jenkins/vendor/bin/"
    }
    stages {
        stage('Prepare') {
            steps {
                sh 'ls -al /home/jenkins'
                sh '/home/jenkins/composer.phar install'
                sh 'rm -rf build/api'
                sh 'rm -rf build/coverage'
                sh 'rm -rf build/logs'
                sh 'rm -rf build/pdepend'
                sh 'rm -rf build/phpdox'
                sh 'mkdir build/api'
                sh 'mkdir build/coverage'
                sh 'mkdir build/logs'
                sh 'mkdir build/pdepend'
                sh 'mkdir build/phpdox'
            }
        }
        stage('PHP Syntax check') {
            steps {
                sh 'parallel-lint --exclude vendor/ .'
            }
        }
        stage('Test') {
            steps {
                sh 'phpunit -c build/phpunit.xml || exit 0'
                xunit(thresholds: [
                        failed(
                                failureNewThreshold: '0',
                                failureThreshold: '0',
                                unstableNewThreshold: '0',
                                unstableThreshold: '0'
                        ),
                        skipped(
                                failureNewThreshold: '0',
                                failureThreshold: '0',
                                unstableNewThreshold: '0',
                                unstableThreshold: '0'
                        )
                ], tools: [
                        PHPUnit(
                                deleteOutputFiles: false,
                                failIfNotNew: true,
                                pattern: 'build/logs/junit.xml',
                                skipNoTestFiles: true,
                                stopProcessingIfError: true
                        )
                ])
            }
        }
        stage('Checkstyle') {
            steps {
                sh 'phpcs --report=checkstyle --report-file=`pwd`/build/logs/checkstyle.xml --standard=PSR2 --extensions=php --ignore=autoload.php,vendor/* . || exit 0'
            }
        }
        stage('Lines of Code') {
            steps {
                sh 'phploc --count-tests --exclude vendor/ --log-csv build/logs/phploc.csv --log-xml build/logs/phploc.xml .'
            }
        }
        stage('Copy paste detection') {
            steps {
                sh 'phpcpd --log-pmd build/logs/pmd-cpd.xml --exclude vendor . || exit 0'
            }
        }
        stage('Software metrics') {
            steps {
                sh 'pdepend --jdepend-xml=build/logs/jdepend.xml --jdepend-chart=build/pdepend/dependencies.svg --overview-pyramid=build/pdepend/overview-pyramid.svg --ignore=vendor .'
            }
        }
        stage('Mess detection') {
            steps {
                sh 'phpmd . xml build/phpmd.xml --reportfile build/logs/pmd.xml --exclude vendor/ || exit 0'
            }
        }
    }
    post {
        always {
            recordIssues(
                    aggregatingResults: true,
                    enabledForFailure: true,
                    tools: [
                            [id: 'checkstyle-uniq-id', pattern: 'build/logs/checkstyle.xml', tool: checkStyle()],
                            [id: 'php-cpd-uniq-id', pattern: 'build/logs/pmd-cpd.xml', tool: cpd()],
                            [id: 'pmd-uniq-id', pattern: 'build/logs/pmd.xml', tool: [$class: 'Pmd']]
                    ]
            )
            archiveArtifacts 'src/'
        }
        success {
            sshPublisher(
                    publishers: [
                            sshPublisherDesc(
                                    configName: 'zelluf',
                                    transfers: [
                                            sshTransfer(
                                                    cleanRemote: false,
                                                    excludes: '',
                                                    execCommand: '',
                                                    execTimeout: 120000,
                                                    flatten: false,
                                                    makeEmptyDirs: false,
                                                    noDefaultExcludes: false,
                                                    patternSeparator: '[, ]+',
                                                    remoteDirectory: 'var/www',
                                                    remoteDirectorySDF: false,
                                                    removePrefix: '',
                                                    sourceFiles: 'src/'
                                            )
                                    ],
                                    usePromotionTimestamp: false,
                                    useWorkspaceInPromotion: false,
                                    verbose: false
                            )
                    ]
            )
            slackSend(
                    baseUrl: 'https://queepjes.slack.com/services/hooks/jenkins-ci/',
                    channel: '#random',
                    color: 'good',
                    message: 'SUCCESS',
                    token: 'TtRWVQlN5ABkGPJobVrsbgKH'
            )

        }
    }
}
