# BUILD STAGE
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /app

# copy project file first (for caching)
COPY *.csproj ./

RUN dotnet restore

# copy source
COPY . .

#build comple for dev vs publish package for deploy
#mvn compile is to dotnet build and mvn package to dotnet publish
RUN dotnet publish -c Release -o out

# RUNTIME STAGE
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=build /app/out .

EXPOSE 8080

ENTRYPOINT ["dotnet", "products.dll"]