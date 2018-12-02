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

                                // Only specify one of these!
                                oAuth2Token: '40f357252cec94f01e5ff3ee840d091139e31a98',
//                                credentialsId: 'github-comment-oauth-access-token',

                                createCommentWithAllSingleFileComments: true,
                                createSingleFileComments: true,
                                commentOnlyChangedContent: false,
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
