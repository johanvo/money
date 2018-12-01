pipeline {
    agent any
    environment {
        PATH = "$PATH:/home/jenkins/vendor/bin/"
    }
    stages {
        stage('Prepare') {
            steps {
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
                sh 'mkdir build/phpmetrics'
                sh 'wget https://github.com/phpmetrics/PhpMetrics/blob/master/build/phpmetrics.phar?raw=true -Ophpmetrics.phar'
            }
        }

        stage('Testing') {
            parallel {
                stage('PHP Syntax check') {
                    steps {
                        sh 'parallel-lint --exclude vendor/ .'
                    }
                }
                stage('Test') {
                    agent {
                        label 'do-the-thing'
                    }
                    steps {
                        sh 'docker run -u `id -u`:`id -g` ' +
                                '-v $(pwd):/tmp/phpunit_base_dir --workdir /tmp/phpunit_base_dir --rm ' +
                                'phpunit/phpunit -c build/phpunit.xml'
                        sh 'ls -l build'
                        sh 'ls -l build/logs'
                        stash (
                                name: 'phpunit_output',
                                includes: 'build/**'
                        )
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
        }

        stage('PHP Metrics') {
            parallel {
                stage('Html report') {
                    steps {
                        sh 'ls -l build'
                        sh 'ls -l build/logs'
                        unstash 'phpunit_output'
                        sh 'ls -l build'
                        sh 'ls -l build/logs'
                        /*
                        * Needs a temporary mount point in /tmp, because as PHPUnit runs inside Docker it generates
                        * reports with non-portable, absolute paths to the analyzed class files in them.
                        * The effect is that PhpMetrics cannot find the files when ran outside PHPUnits docker file.
                        */
                        sh 'ln -s $(pwd) /tmp/phpunit_base_dir'
                        sh 'php phpmetrics.phar --junit=build/logs/junit.xml --report-html=build/phpmetrics/ ./ || exit 0'
                        sh 'rm /tmp/phpunit_base_dir'
                        script {
                            publishHTML(target: [
                                    allowMissing         : false,
                                    alwaysLinkToLastBuild: false,
                                    keepAll              : true,
                                    reportDir            : 'build/phpmetrics/',
                                    reportFiles          : '*',
                                    reportTitles         : "",
                                    reportName           : "PhpMetrics"
                            ])
                        }
                    }
                }
                stage('Violations report') {
                    steps {
                        sh 'php phpmetrics.phar --report-violations=build/logs/phpmetrics-violations.xml ./'
                    }
                }

            }
        }

        stage('Deliver') {
            steps {
                sshPublisher(
                        publishers: [
                                sshPublisherDesc(
                                        configName: 'zelluf',
                                        transfers: [
                                                sshTransfer(
                                                        cleanRemote: false,
                                                        excludes: '',
                                                        execTimeout: 120000,
                                                        flatten: false,
                                                        makeEmptyDirs: false,
                                                        noDefaultExcludes: false,
                                                        patternSeparator: '[, ]+',
                                                        remoteDirectory: "srv/www/git/${currentBuild.projectName}/$BUILD_TAG",
                                                        remoteDirectorySDF: false,
                                                        removePrefix: 'src',
                                                        sourceFiles: 'src/',
                                                        execCommand: "cd srv/www " +
                                                                "&& rm -f $GIT_BRANCH" +
                                                                "&& ln -s git/${currentBuild.projectName}/$BUILD_TAG $GIT_BRANCH"
                                                )
                                        ],
                                        usePromotionTimestamp: false,
                                        useWorkspaceInPromotion: false,
                                        verbose: false
                                )
                        ]
                )
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
            archiveArtifacts 'build/'
        }
        success {
            slackSend(
                    baseUrl: 'https://queepjes.slack.com/services/hooks/jenkins-ci/',
                    channel: '#random',
                    color: 'good',
                    message: "successfully finished ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|details>)",
                    token: 'TtRWVQlN5ABkGPJobVrsbgKH'
            )
        }
        failure {
            slackSend(
                    baseUrl: 'https://queepjes.slack.com/services/hooks/jenkins-ci/',
                    channel: '#random',
                    color: 'danger',
                    message: "job ${env.JOB_NAME} ${env.BUILD_NUMBER} FAILED (<${env.BUILD_URL}|details>)",
                    token: 'TtRWVQlN5ABkGPJobVrsbgKH'
            )
        }
    }
}
