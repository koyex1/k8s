# to start project
dotnet new webapi -n productService 

# install dependencies and modify productService.csproj
# exactly like npm install npgsql 
dotnet add package Npgsql

# install the dependecies written in productService.csproj
# exactly like npm install
dotnet restore

# repository
doesnt store in local directory like npm does it globally into ~/.nuget/packages/

# run locally
dotnet run

# build 
dotnet build

# similarities with java
pom.xml .csproj, mvn dependency:go-offline dotnet restore, mvn package dotnet publish, .jar .dll, java -jar dotnet app.dll

