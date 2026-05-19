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


# just disvoered
you can build a single yaml file that you will use kubectl to apply later, using the helm command - helm template auth ./charts/auth > output.yaml