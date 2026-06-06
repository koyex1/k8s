name
permissions
on.workflow_calls, on.push [branches], on.pull_request [branches]
env
jobs.{{jobName}} [runs-on, defaults.run.working-directory, steps]

#work-directory does not work with uses.with. path commands are like your normal cd path commands. Afterall the global work-dir falls under default.RUN.work-directory. emphasis on the RUN.
#work-directory at global level works for only run commands. and you can also scope work-directory for that particular run steps.

# rules gitaction
github/workflows everything must be inside this directory and there should not be another directory created.

# ci cd pipeline look into it
 ci code, ci terraform with atlantis, cd ec2 with ssh(to do docker run), cd ec2 with ssh(to do npm start), cd k8s with kubeconfig(to do k apply or helm install), cd k8s with argocd(none image changes), cd k8s(image via value.yaml or deploy.yaml) with argocd. 

# For node application
ci - lint, test(npm test) with reports, sonar (reusable), dependency scan with scan (reusable), build via docker with image scan and reports (reusable), push image(reusable).
cd - cd ec2 with ssh(to do docker run), cd ec2 with ssh(to do npm start)
                          # cd k8s with kubeconfig(to do k apply or helm install), cd k8s with argocd(none image changes), cd k8s(image via value.yaml or deploy.yaml) with argocd


# now how do we set these k8s yaml files with the image 
- for k apply or helm install you use kubectl set image as a run command in your cd pipeline.
- for argocd you use gitaction variables on your images. where you use image: imageName:${{github_commit_sha}}

# deploying applicaitons
either the server is prepared for you(e.g using terraform to launch an ec2 instance and installing runtime environment, pm2, for monolith app, or to lauch eks for microservice apps) or the server is not prepare for you and you setup runtime etc during cd (slow deployment though)

# next container, helm, kubernetes deployment files ( 2 simple rules SS(server & source of truth))
it is either you are editing right in the server (most - using flags like set image, using sed, using yq, using TAG=v1.2 for docker compose, helm with either its values.yaml file or --set flag) or you are editing it from github(argocd, fluxcd).
#set image used in k8s for setting image key value
#sed stream editor for search a file and replacing
#helm render template generates a static deployment yaml file from your values.yaml and template. then you can now kubectl apply this static file. otherwise you can just use helm straight to deploy
#avoid these because they are not prod friendly - kubectl run, dry-run, docker run, kubectl create.
# so to version the changes without gitops you will do a git push of your current deployment to github > template, template manifest, 
# with argocd cd is completely taken out of gitaction pipeline.


# 0. gitaction deployment examples
https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/azure-kubernetes-service

${{ github.event.workflow_run.conclusion == 'success' }} && 


# 1. KUBECTL DIRECT DEPLOY (CI → CLUSTER)
name: kubectl-cd

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myrepo/auth:${{ github.sha }} .

      - name: Push image
        run: |
          docker login -u ${{ secrets.DOCKER_USER }} -p ${{ secrets.DOCKER_PASS }}
          docker push myrepo/auth:${{ github.sha }}

      - name: Setup kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config

      - name: Deploy via kubectl
        run: |
          kubectl set image deployment/auth auth=myrepo/auth:${{ github.sha }}
          kubectl rollout status deployment/auth
# 2. KUBECTL APPLY YAML (RENDERED MANIFESTS)
name: kubectl-apply-cd

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: docker build -t myrepo/auth:${{ github.sha }} .
      - run: docker push myrepo/auth:${{ github.sha }}

      - name: Render manifest
        run: |
          sed "s|IMAGE_TAG|${{ github.sha }}|g" k8s/deployment.yaml > out.yaml

      - name: Apply
        run: |
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config
          kubectl apply -f out.yaml
# 3. HELM DEPLOY (NO GITOPS)
name: helm-cd

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: docker build -t myrepo/auth:${{ github.sha }} .
      - run: docker push myrepo/auth:${{ github.sha }}

      - name: Helm deploy
        run: |
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config

          helm upgrade --install auth ./helm/auth-chart \
            --set image.repository=myrepo/auth \
            --set image.tag=${{ github.sha }}
# 4. HELM TEMPLATE → KUBECTL APPLY
name: helm-template-cd

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: docker build -t myrepo/auth:${{ github.sha }} .
      - run: docker push myrepo/auth:${{ github.sha }}

      - name: Render Helm to YAML
        run: |
          helm template auth ./helm/auth-chart \
            --set image.tag=${{ github.sha }} > rendered.yaml

      - name: Apply
        run: |
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config
          kubectl apply -f rendered.yaml
# 5. BASIC GITOPS (ARgoCD STYLE)

👉 CI ONLY UPDATES GIT (no kubectl)

name: gitops-cd

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: docker build -t myrepo/auth:${{ github.sha }} .
      - run: docker push myrepo/auth:${{ github.sha }}

      - name: Update manifest repo
        run: |
          git clone https://github.com/org/k8s-manifests.git
          cd k8s-manifests

          sed -i "s|image: myrepo/auth:.*|image: myrepo/auth:${{ github.sha }}|g" auth/deployment.yaml

          git config user.name "github-actions"
          git config user.email "ci@github.com"

          git commit -am "update auth image"
          git push
# 6. HELM + GITOPS
name: helm-gitops-cd

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: docker build -t myrepo/auth:${{ github.sha }} .
      - run: docker push myrepo/auth:${{ github.sha }}

      - name: Update GitOps repo values
        run: |
          git clone https://github.com/org/k8s-gitops.git
          cd k8s-gitops

          yq e '.image.tag = "${{ github.sha }}"' -i auth/values.yaml

          git config user.name "github-actions"
          git config user.email "ci@github.com"

          git commit -am "update image tag"
          git push
# 7. MULTI-SERVICE (MATRIX DEPLOYMENT)
name: multi-service-cd

jobs:
  deploy:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        service: [auth, payment, order]

    steps:
      - uses: actions/checkout@v4

      - run: docker build -t myrepo/${{ matrix.service }}:${{ github.sha }} ./services/${{ matrix.service }}

      - run: |
          docker login -u ${{ secrets.DOCKER_USER }} -p ${{ secrets.DOCKER_PASS }}
          docker push myrepo/${{ matrix.service }}:${{ github.sha }}

      - name: Deploy via kubectl
        run: |
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config
          kubectl set image deployment/${{ matrix.service }} \
            ${{ matrix.service }}=myrepo/${{ matrix.service }}:${{ github.sha }}

          kubectl rollout status deployment/${{ matrix.service }}
# using git checkout + kubectl
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config

      - name: Deploy to Kubernetes
        run: |
          cd kubernetes/manifests
          
          # Update image tag (using sed or yq)
          sed -i "s|image: myapp:.*|image: myapp:${{ github.sha }}|g" deployment.yaml
          
          # Apply all manifests
          kubectl apply -f deployment.yaml
          kubectl apply -f service.yaml
          kubectl apply -f configmap.yaml
          
          # Wait for rollout
          kubectl rollout status deployment/myapp --timeout=5m

# using git checkout + helm
jobs: what can trigger this buid can be success from ci or change from kubenetes dir in your repo(here you will not need to set or sed any value because you would have made does changes before git pushing)
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Helm
        uses: azure/setup-helm@v3

      - name: Set up kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config

      - name: Deploy with Helm
        run: |
          cd kubernetes/chart
          
          # Helm handles the image tag replacement natively
          helm upgrade --install myapp ./ \
            --set image.tag=${{ github.sha }} \
            --set image.repository=myregistry/myapp \
            --namespace default \
            --wait \
            --timeout 5m


# continuos deliver via jenkins, gitaction and api(through your own custom dashboards)
// Jenkins pipeline - requires manual click to run
pipeline {
    parameters {
        string(name: 'VERSION', defaultValue: 'latest', description: 'Image tag to deploy')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    }
    stages {
        stage('Deploy') {
            steps {
                sh "helm upgrade --install myapp ./chart --set image.tag=${params.VERSION}"
            }
        }
    }
}


curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/owner/repo/actions/workflows/manual-deploy.yml/dispatches \
  -d '{
    "ref": "main",
    "inputs": {
      "environment": "staging",
      "version": "v1.2.3"
    }
  }'



# .github/workflows/manual-deploy.yml
name: Manual Deployment (Continuous Delivery)

on:
  workflow_dispatch:  # 👈 THIS is your "Build with Parameters" button
    inputs:
      environment:
        description: 'Where to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - production
      version:
        description: 'Image tag or commit SHA'
        required: true
        default: 'latest'
      replicas:
        description: 'Number of replicas'
        required: false
        default: '3'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy selected version
        run: |
          helm upgrade --install myapp ./chart \
            --namespace ${{ github.event.inputs.environment }} \
            --set image.tag=${{ github.event.inputs.version }} \
            --set replicas=${{ github.event.inputs.replicas }}
      
      - name: Verify deployment
        run: |
          kubectl rollout status deployment/myapp \
            --namespace ${{ github.event.inputs.environment }}

# on differnt environments pipeline
for terraform i have to change directory, or use workspace command to change workspace
for k8s i have to use set flag with different value.yaml file
for cd i have to use conditonal functions based on inputs [dev, test, staging, prod] and then for each condition set flag with differnt value.yaml file.

# git flow
feature branch--merged request --> dev branch --mr--> test branch --mr --> staging branch --mr--> main/prod branch
now: feature branch --mr--> main branch(input filters for dev, test, staging, prod)


# just disvoered
you can build a single yaml file that you will use kubectl to apply later, using the helm command - helm template auth ./charts/auth > output.yaml