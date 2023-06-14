import Architecture

@main
struct App: Application {
    var scenes: [any Scene] { [
        //Service(sdk: SDK(), package: Package(path: "/Users/purpln/Developer/project")),
        Test()
    ] }
}
