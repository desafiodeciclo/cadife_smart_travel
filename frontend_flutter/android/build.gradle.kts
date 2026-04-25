allprojects {
    repositories {
        google()
        mavenCentral()
    }
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { ext ->
            if (ext.namespace == null) {
                val manifestFile = projectDir.resolve("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val packageName = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                        .newDocumentBuilder()
                        .parse(manifestFile)
                        .documentElement
                        .getAttribute("package")
                    if (packageName.isNotEmpty()) ext.namespace = packageName
                }
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
