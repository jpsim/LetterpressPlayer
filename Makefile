test:
	which ios-sim || brew install ios-sim
	xcodebuild -target LetterCheaterTests -sdk iphonesimulator -configuration Debug RUN_UNIT_TEST_WITH_IOS_SIM=YES