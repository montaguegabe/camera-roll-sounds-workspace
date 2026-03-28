import ProjectDescription

let project = Project(
    name: "CameraRollSounds",
    options: .options(
        automaticSchemesOptions: .disabled
    ),
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "E6GA9X89TN",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        .target(
            name: "CameraRollSounds",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.mindfulmakers.camerarollsounds",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "NSPhotoLibraryUsageDescription": "Select photos to generate ambient sounds",
                "NSAppTransportSecurity": .dictionary([
                    "NSAllowsArbitraryLoads": .boolean(true),
                ]),
            ]),
            sources: ["CameraRollSounds/**"],
            resources: ["CameraRollSounds/Assets.xcassets", "CameraRollSounds/Preview Content/**"],
            dependencies: [
                .external(name: "OpenbaseShared"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_PREVIEWS": "YES",
                ]
            )
        ),
        .target(
            name: "CameraRollSoundsTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "com.mindfulmakers.camerarollsounds.tests",
            deploymentTargets: .iOS("18.0"),
            sources: ["CameraRollSoundsTests/**"],
            dependencies: [
                .target(name: "CameraRollSounds"),
            ]
        ),
        .target(
            name: "CameraRollSoundsUITests",
            destinations: [.iPhone, .iPad],
            product: .uiTests,
            bundleId: "com.mindfulmakers.camerarollsounds.uitests",
            deploymentTargets: .iOS("18.0"),
            sources: ["CameraRollSoundsUITests/**"],
            dependencies: [
                .target(name: "CameraRollSounds"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "CameraRollSounds",
            shared: true,
            buildAction: .buildAction(targets: ["CameraRollSounds"]),
            testAction: .targets(["CameraRollSoundsTests", "CameraRollSoundsUITests"]),
            runAction: .runAction(configuration: "Debug", executable: "CameraRollSounds")
        ),
    ]
)
