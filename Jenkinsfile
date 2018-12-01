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
    }
    post {
        always {
            archiveArtifacts 'src/'
            archiveArtifacts 'build/reports/'
        }
    }
}
