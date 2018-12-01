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
                    steps {
                        sh 'phpunit -c build/phpunit.xml || exit 0'
                    }
                }
            }
        }

        stage('PHP Metrics') {
            parallel {
                stage('Html report') {
                    steps {
                        sh 'php phpmetrics.phar --junit=build/logs/junit.xml --report-html=build/phpmetrics/ ./'
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

            }
        }
    }
    post {
        always {
            archiveArtifacts 'src/'
            archiveArtifacts 'build/'
        }
    }
}
