pipeline {
    agent any 

    stages {
        stage('Prepare') {
            steps {
                // debug
                sh 'PATH=$PATH:/home/jenkins/vendor/bin/ && echo $PATH'
                sh 'echo $PATH'
                sh 'ls -al /home/jenkins'
                
                // normal commands
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
                sh '/home/jenkins/vendor/bin/parallel-lint --exclude vendor/ .'
            }
        }

        stage('Test'){
            steps {
                sh '/home/jenkins/vendor/bin/phpunit -c build/phpunit.xml || exit 0'
                xunit (
                    thresholds: [
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
                    ],
                    tools: [
                        PHPUnit(
                            deleteOutputFiles: false, 
                            failIfNotNew: true, 
                            pattern: 'build/logs/junit.xml', 
                            skipNoTestFiles: true, 
                            stopProcessingIfError: true
                        )
                    ]
                )
                script {
                  publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'build/testdox/',
                    reportFiles: 'index.html',
                    reportTitles: "",
                    reportName: "testdox_Report"
                  ])
                }
            }
        }

        stage('Checkstyle') {
            steps {
                sh '/home/jenkins/vendor/bin/phpcs --report=checkstyle --report-file=`pwd`/build/logs/checkstyle.xml --standard=PSR2 --extensions=php --ignore=autoload.php --ignore=vendor/ . || exit 0'
                checkstyle pattern: 'build/logs/checkstyle.xml'
            }
        }

        stage('Lines of Code') {
            steps {
                sh '/home/jenkins/vendor/bin/phploc --count-tests --exclude vendor/ --log-csv build/logs/phploc.csv --log-xml build/logs/phploc.xml .'
            }
        }

        stage('Copy paste detection') {
            steps {
                sh '/home/jenkins/vendor/bin/phpcpd --log-pmd build/logs/pmd-cpd.xml --exclude vendor . || exit 0'
                dry canRunOnFailed: true, pattern: 'build/logs/pmd-cpd.xml'
            }
        }

        stage('Software metrics') {
            steps {
                sh '/home/jenkins/vendor/bin/pdepend --jdepend-xml=build/logs/jdepend.xml --jdepend-chart=build/pdepend/dependencies.svg --overview-pyramid=build/pdepend/overview-pyramid.svg --ignore=vendor .'
            }
        }
    }

    post {
        always {
            junit 'build/logs/junit.xml'
            recordIssues enabledForFailure: true, tools: [[tool: [$class: 'CheckStyle']]]
            archiveArtifacts 'build/'
            archiveArtifacts ''
        }
    }
}
