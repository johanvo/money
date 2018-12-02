pipeline {
    agent any
    environment {
        PATH = "$PATH:/home/jenkins/vendor/bin/"
    }
    stages {
        stage('Prepare') {
            steps {
                sh '/home/jenkins/composer.phar install'
                sh 'rm -rf build/reports'
                sh 'mkdir build/reports'
                sh 'wget https://github.com/phpmetrics/PhpMetrics/blob/master/build/phpmetrics.phar?raw=true -Ophpmetrics.phar'
            }
        }

        stage('PHP Metrics') {
            parallel {
                stage('Violations report') {
                    steps {
                        sh 'php phpmetrics.phar --report-violations=build/reports/phpmetrics-violations.xml ./'
                    }
                }

            }
        }
        stage('Comment on Github PR') {
            when {
                changeRequest
            }
            steps {
                step([
                        $class: 'ViolationsToGitHubRecorder',
                        config: [
                                gitHubUrl: 'https://api.github.com/',
                                repositoryOwner: 'johanvo',
                                repositoryName: 'money',
                                pullRequestId: '$CHANGE_ID',

                                // Only specify one of these!
                                oAuth2Token: ' 09036ea7261b6c8ae25e45315d18b0f00368c628',
                                // github-comment-oauth-access-token

                                createCommentWithAllSingleFileComments: true,
                                createSingleFileComments: true,
                                commentOnlyChangedContent: true,
                                minSeverity: 'INFO',
                                keepOldComments: false,
                                violationConfigs: [
                                        [ pattern: 'build/reports/checkstyle.xml', parser: 'CHECKSTYLE', reporter: 'Checkstyle' ],
                                        [ pattern: 'build/reports/phpmetrics-violations.xml', parser: 'PMD', reporter: 'PMD' ],
                                ]
                        ]
                ])
            }
        }
    }

    post {
        always {
            archiveArtifacts 'src/'
            archiveArtifacts 'build/reports/'
        }
    }
}
