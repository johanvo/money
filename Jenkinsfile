pipeline {
    agent any 

    stages {
        stage('Prepare') {
            steps {
                sh 'PATH=$PATH:/home/jenkins/vendor/bin/'
                sh 'echo $PATH'
                sh 'ls -l /home/jenkins'
                sh 'ls -l /home/jenkins/vendor'
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
                sh 'ls -l'
                sh 'ls -l vendor/bin/'
                sh '/home/jenkins/vendor/bin/parallel-lint --exclude vendor/ .'
            }
        }
        
        stage('Test'){
            steps {
                sh 'vendor/bin/phpunit -c build/phpunit.xml || exit 0'
                step($class: 'XUnitBuilder',
                    thresholds: [[$class: 'FailedThreshold', unstableThreshold: '1']],
                    tools: [[$class: 'JUnitType', pattern: 'build/logs/junit.xml']]
                )
                script {
                  publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: false,
                    reportDir: 'build/coverage',
                    reportFiles: 'index.html',
                    reportTitles: "SimpleCov Report",
                    reportName: "SimpleCov Report"
                  ])
                }
                step([$class: 'CloverPublisher', cloverReportDir: 'build/coverage', cloverReportFileName: 'build/logs/clover.xml'])
                step([$class: 'Mailer', notifyEveryUnstableBuild: true, recipients: '', sendToIndividuals: false])
                /* BROKEN step([$class: 'hudson.plugins.crap4j.Crap4JPublisher', reportPattern: 'build/logs/crap4j.xml', healthThreshold: '10']) */
            }
        }
        stage('Checkstyle') {
            steps {
                sh 'vendor/bin/phpcs --report=checkstyle --report-file=`pwd`/build/logs/checkstyle.xml --standard=PSR2 --extensions=php --ignore=autoload.php --ignore=vendor/ . || exit 0'
                checkstyle pattern: 'build/logs/checkstyle.xml'
            }
        }
        stage('Lines of Code') { steps { sh 'vendor/bin/phploc --count-tests --exclude vendor/ --log-csv build/logs/phploc.csv --log-xml build/logs/phploc.xml .' } }
        stage('Copy paste detection') {
            steps {
                sh 'vendor/bin/phpcpd --log-pmd build/logs/pmd-cpd.xml --exclude vendor . || exit 0'
                dry canRunOnFailed: true, pattern: 'build/logs/pmd-cpd.xml'
            }
        }
        /* -- SLOW
        stage('Mess detection') {
            steps {
                sh 'vendor/bin/phpmd . xml build/phpmd.xml --reportfile build/logs/pmd.xml --exclude vendor/ || exit 0'
                pmd canRunOnFailed: true, pattern: 'build/logs/pmd.xml'
            }
        }
        */
        stage('Software metrics') { steps { sh 'vendor/bin/pdepend --jdepend-xml=build/logs/jdepend.xml --jdepend-chart=build/pdepend/dependencies.svg --overview-pyramid=build/pdepend/overview-pyramid.svg --ignore=vendor .' } }
        /* -- also SLOW?
        stage('Generate documentation') { steps { sh 'vendor/bin/phpdox -f build/phpdox.xml' } }
        */
    }
}
