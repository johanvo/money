pipeline {
    agent any
    environment {
        PATH = "$PATH:/home/jenkins/vendor/bin/"
    }
    stages {
        stage('0 - Setup') {
            steps {
                sh '/home/jenkins/composer.phar install'
                sh 'rm -rf build/reports/pdepend'
                sh 'rm -rf build/reports'
                sh 'mkdir build/reports'
                sh 'mkdir build/reports/pdepend'
                sh 'wget https://github.com/phpmetrics/PhpMetrics/blob/master/build/phpmetrics.phar?raw=true -Ophpmetrics.phar'
            }
        }

        stage('1 - Testing') {
            agent {
                label 'do-the-thing'
            }
            steps {
                sh 'docker run -u `id -u`:`id -g` ' +
                        '-v $(pwd):/tmp/phpunit_base_dir --workdir /tmp/phpunit_base_dir --rm ' +
                        'phpunit/phpunit -c build/phpunit.xml'
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
                                failureThreshold: '1',
                                unstableNewThreshold: '0',
                                unstableThreshold: '1'
                        )
                ], tools: [
                        PHPUnit(
                                deleteOutputFiles: false,
                                failIfNotNew: true,
                                pattern: 'build/reports/junit.xml',
                                skipNoTestFiles: true,
                                stopProcessingIfError: true
                        )
                ])
            }
        }

        stage('2 - Quality check') {
            failFast true
            parallel {
                stage('PHP Syntax check') {
                    steps {
                        sh 'parallel-lint --exclude vendor/ .'
                    }
                }
                stage('Checkstyle') {
                    steps {
                        sh 'phpcs --report=checkstyle --report-file=`pwd`/build/reports/checkstyle.xml --standard=PSR2 --extensions=php --ignore=autoload.php,vendor/* . || exit 0'
                    }
                }
                stage('PhpMetrics') {
                    steps {
                        unstash 'phpunit_output'
                        /*
                        * Needs a temporary mount point in /tmp, because as PHPUnit runs inside Docker it generates
                        * reports with non-portable, absolute paths to the analyzed class files in them.
                        * The effect is that PhpMetrics cannot find the files when ran outside PHPUnits docker file.
                        */
                        sh 'ln -s $(pwd) /tmp/phpunit_base_dir'
                        sh 'php phpmetrics.phar --junit=build/reports/junit.xml --report-html=build/reports/phpmetrics/ ./ || exit 0'
                        sh 'rm /tmp/phpunit_base_dir'
                        script {
                            publishHTML(target: [
                                    allowMissing         : false,
                                    alwaysLinkToLastBuild: false,
                                    keepAll              : true,
                                    reportDir            : 'build/reports/phpmetrics/',
                                    reportFiles          : '*',
                                    reportTitles         : "",
                                    reportName           : "PhpMetrics"
                            ])
                        }
                    }
                }
                stage('Violations report') {
                    steps {
                        sh 'php phpmetrics.phar --report-violations=build/reports/phpmetrics-violations.xml ./'
                    }
                }
                stage('Lines of Code') {
                    steps {
                        sh 'phploc --count-tests --exclude vendor/ --log-csv build/reports/phploc.csv --log-xml build/reports/phploc.xml .'
                    }
                }
                stage('Copy paste detection') {
                    steps {
                        sh 'phpcpd --log-pmd build/reports/pmd-cpd.xml --exclude vendor . || exit 0'
                    }
                }
                stage('Dependency charts') {
                    steps {
                        sh 'pdepend --jdepend-xml=build/reports/pdepend/jdepend.xml --jdepend-chart=build/reports/pdepend/dependencies.svg --overview-pyramid=build/reports/pdepend/overview-pyramid.svg --ignore=vendor .'
                    }
                }
                stage('Mess detection') {
                    steps {
                        sh 'phpmd . xml build/reports/phpmd.xml --reportfile build/reports/pmd.xml --exclude vendor/ || exit 0'
                    }
                }
            }
        }

        stage('3 - Delivery') {
            when {
                branch 'master'
            }
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

        stage('4 - Comment on Github PR') {
            when {
                changeRequest()
            }
            steps {
                step([
                        $class: 'ViolationsToGitHubRecorder',
                        config: [
                                gitHubUrl: 'https://api.github.com/',
                                repositoryOwner: 'johanvo',
                                repositoryName: 'money',
                                pullRequestId: '$CHANGE_ID',

                                credentialsId: 'github-comment-oauth-access-token',

                                createCommentWithAllSingleFileComments: false,
                                createSingleFileComments: true,
                                commentOnlyChangedContent: false,
                                minSeverity: 'INFO',
                                keepOldComments: false,
                                violationConfigs: [
                                        [ pattern: '.*build/reports/checkstyle\\.xml\$', parser: 'CHECKSTYLE', reporter: 'Checkstyle' ],
                                        [ pattern: '.*build/reports/phpmetrics-violations\\.xml\$', parser: 'PMD', reporter: 'PMD' ],
                                ]
                        ]
                ])
            }
        }
    }

    post {
        always {
            recordIssues(
                    aggregatingResults: true,
                    enabledForFailure: true,
                    tools: [
                            [id: 'checkstyle-uniq-id', pattern: 'build/reports/checkstyle.xml', tool: checkStyle()],
                            [id: 'php-cpd-uniq-id', pattern: 'build/reports/pmd-cpd.xml', tool: cpd()],
                            [id: 'pmd-uniq-id', pattern: 'build/reports/pmd.xml', tool: [$class: 'Pmd']]
                    ]
            )
            archiveArtifacts 'src/'
            archiveArtifacts 'build/reports/'
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
