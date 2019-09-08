def NotifyFailure() {
  emailext (
    subject: 'Jenkins: Pipeline failed: $PROJECT_NAME - #$BUILD_NUMBER',
    body: 'Pipeline failed. Please check the console output at $BUILD_URL . \n\n \
    ${CHANGES} \n\n -------------------------------------------------- \n \
    ${BUILD_LOG, maxLines=100, escapeHtml=false}',
    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
  )
 }

def NotifySuccess() {
  emailext (
    subject: 'Jenkins: Pipeline succeeded: $PROJECT_NAME - #$BUILD_NUMBER',
    body: 'Pipeline succeeded. Please check the console output at $BUILD_URL . \n\n \
    ${CHANGES} \n\n -------------------------------------------------- \n \
    ${BUILD_LOG, maxLines=100, escapeHtml=false}',
    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
  )
}

pipeline {
  agent any

  environment {
    IMAGE_NAME = 'app-demo'
    GIT_COMMIT = GIT_COMMIT.take(8)
    REPOSITORY = "ogrigor/demo-app"
  }

  stages {
    stage('SCM Checkout') {
      steps {
        sh 'git checkout $BRANCH_NAME'
        sh 'git pull'
      }
      post {
        failure {
          NotifyFailure()
        }
      }
    }

    stage('Build') {
      steps {
        sh 'docker build -t $IMAGE_NAME:$BRANCH_NAME.$GIT_COMMIT .'
      }
      post {
        failure {
          NotifyFailure()
        }
      }
    }

    stage('Integration Tests') {
      steps {
        sh 'docker run --rm $IMAGE_NAME:$BRANCH_NAME.$GIT_COMMIT npm test'
        }
      post {
        failure {
          NotifyFailure()
        }
          success {
            publishHTML (target: [
              allowMissing: false,
              alwaysLinkToLastBuild: false,
              keepAll: true,
              reportDir: 'coverage/lcov-report',
              reportFiles: 'index.html',
              reportName: "RCov Report"
              ])
            }
      }
    }

    stage('E2E Tests') {
      steps {
        sh 'docker run --name $IMAGE_NAME-$BUILD_NUMBER $IMAGE_NAME:$BRANCH_NAME.$GIT_COMMIT npm run test:e2e'
      }
      post {
        failure {
          NotifyFailure()
          // We do not need images which are not passed tests
          sh 'docker container rm $IMAGE_NAME-$BUILD_NUMBER'
          sh 'docker rmi -f $IMAGE_NAME:$BRANCH_NAME.$GIT_COMMIT'
        }
        success {
            // add 'tested' tag
            sh 'docker tag $IMAGE_NAME:$BRANCH_NAME.$GIT_COMMIT $IMAGE_NAME:tested.$BRANCH_NAME.$GIT_COMMIT'
            script {
              if (env.BRANCH_NAME != 'master') {
                echo 'Push to local Registry'
                sh 'docker commit $IMAGE_NAME-$BUILD_NUMBER $IMAGE_NAME:tested.$BRANCH_NAME.$GIT_COMMIT'
              } else {
                echo 'Label image'
                sh 'docker tag $IMAGE_NAME:tested.$BRANCH_NAME.$GIT_COMMIT $REPOSITORY:release-$GIT_COMMIT'
                sh 'docker tag $REPOSITORY:release-$GIT_COMMIT $REPOSITORY:latest'
                echo 'Push to remote public Repository'
                withCredentials([usernamePassword(credentialsId: 'dockerHub',
            passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                sh 'docker push $REPOSITORY:release-$GIT_COMMIT'
                sh 'docker push $REPOSITORY:latest'
                }
              }
            }
        }
      }
    }
  }

  post('Notify') {
    success {
      NotifySuccess()
    }
    failure {
      echo 'Remove failed imamge'
      sh 'docker rmi -f $IMAGE_NAME:$BRANCH_NAME.$GIT_COMMIT || exit 0'
    }
  }
}
