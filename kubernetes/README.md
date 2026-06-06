# new release
each microservice has a helm-chart so a helm install [new release] -set image -set serviceName will create a new updated microservice with a new service name that i can go to the httproute to route to this new service either via(blule-green, or weighted - canary). this makes rollback hard eventhough it is achiveable because 

# rollback 
because rollback is easily achieved if you are on the same release because you just simply hit a helm rollback [release name] 3. This is possilbe when you use helm upgrade [current release] --set image.(as it uses the update strategy in you k8s - rollingupdate or recreate)

# argocd rollout - things get interesting here
argocd controls traffic management by replacing your deployment file with Rollout. it still has all the deployment templates only thing it did is include a strategy that a normal k8s deployment yaml doesnt have - it adds the strategies canary & blueGreen, which might need you to point to your 2 services as a value to a key & also point to http-route(so a http-route per service will suffice here for this reason)

# simple hack (for good mental image of the routing )
http route --> services --> deployment
X - not deployment --> services --> httproute 