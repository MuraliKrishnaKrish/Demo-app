pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-agent
  containers:
  - name: tools
    image: alpine/git:latest
    command: ['cat']
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['/busybox/cat']
    tty: true
    env:
    - name: AWS_REGION
      value: us-east-1
    - name: AWS_SDK_LOAD_CONFIG
      value: "true"
'''
    }
  }

  environment {
    ACCOUNT_ID   = '653601357856'
    GITHUB_USER  = 'MuraliKrishnaKrish'
    ECR_REPO     = "${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/demo-app"
    IMAGE_TAG    = "v${env.BUILD_NUMBER}"
  }

  stages {
    stage('Test') {
      steps {
        container('tools') {
          sh 'sh test.sh'
        }
      }
    }

    stage('Build & Push to ECR') {
      when { branch 'main' }
      steps {
        container('kaniko') {
          sh '''
            mkdir -p /kaniko/.docker
            echo '{"credsStore":"ecr-login"}' > /kaniko/.docker/config.json
            /kaniko/executor \
              --context=dir://. \
              --dockerfile=Dockerfile \
              --destination=${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Update GitOps Repo (Argo CD)') {
      when { branch 'main' }
      steps {
        container('tools') {
          withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
            sh '''
              git config --global user.email "ci@demo.local"
              git config --global user.name "Jenkins CI"
              rm -rf demo-gitops
              git clone https://${GIT_USER}:${GIT_PASS}@github.com/${GITHUB_USER}/demo-gitops.git
              cd demo-gitops
              sed -i "s|image: .*|image: ${ECR_REPO}:${IMAGE_TAG}|g" deployment.yaml
              git add deployment.yaml
              git commit -m "Deploy demo-app ${IMAGE_TAG}" || echo "No changes"
              git push origin main
            '''
          }
        }
      }
    }
  }
}
