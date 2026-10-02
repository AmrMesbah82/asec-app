allprojects {
    repositories {
        google()
        mavenCentral()
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
// Some plugins (e.g. file_picker 8.x) hard-code compileSdk 34, but newer
// AndroidX deps require 36. Force every Android library plugin to compile
// against 36. This only changes the compile SDK, not minSdk/targetSdk.
subprojects {
    val forceCompileSdk: Project.() -> Unit = {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { it.compileSdk = 36 }
    }
    if (project.name != "app") {
        if (project.state.executed) project.forceCompileSdk()
        else project.afterEvaluate { forceCompileSdk() }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
