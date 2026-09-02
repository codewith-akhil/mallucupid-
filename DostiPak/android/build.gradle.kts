plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

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
// AGP 9 reads only the new DSL, so plugins that set a low compileSdk via the old
// DSL are not corrected by the Flutter Gradle plugin anymore. Force every library
// subproject to compile against the same SDK as the app to satisfy AAR metadata
// checks (androidx.fragment 1.7.1 / androidx.window 1.2.0 require compileSdk 34+).
// NOTE: must be registered before evaluationDependsOn(":app") runs below.
subprojects {
    afterEvaluate {
        if (name == "app") return@afterEvaluate
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val setter = androidExt.javaClass.methods.firstOrNull { m ->
            m.name == "setCompileSdk" &&
                m.parameterTypes.firstOrNull() in listOf(Int::class.javaPrimitiveType, Integer::class.java)
        }
        setter?.invoke(androidExt, 36)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
