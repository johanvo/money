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
