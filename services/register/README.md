# Maven doesn’t magically know how to turn your app into a runnable Spring Boot app.
The plugin is what teaches Maven how to do Spring Boot–specific work.

# .mvn .gitattributes .gitignore HELP.md mvnw mvnw.cmd
for only when mvn is installed locally. otherwise apt install mvn
suffices.

# /root/.m2/repository/ just like /modules but not inside
your project directory but the root directory. sort of
like a global repo.

# with your pom.xml file, java jdk 17 and mvn installed globally, mvn spring-boot:run command is all you need to start your project in dev. note file structure is src/main/java/com/app/<<your project>>.
src/main/resources/<<application.properties>>
src/test/java/com/app/<<you test project>>

# spring-boot:run creates a target file with your jar build. in ./target

# so mvn spring-boot:run downloads all your dependencies into /target and after completing this process. starts your applicaiton.


# steps
code -> build/compile -> package/publish
.java -> .dll & .pdb -> .dll & json

# here is where i will be make changes to register for trigger gitactio
git reset --soft HEAD~1