allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val library = extensions.getByType<com.android.build.gradle.LibraryExtension>()
        if (library.namespace == null) {
            val manifestFile = projectDir.resolve("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val builderFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                val builder = builderFactory.newDocumentBuilder()
                val document = builder.parse(manifestFile)
                val packageName = document.documentElement.getAttribute("package")
                if (packageName.isNotEmpty()) {
                    library.namespace = packageName
                }
            }
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
