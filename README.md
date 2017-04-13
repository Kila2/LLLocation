# LLLocation
- [Features](#features)
- [Usage](#usage)
- ## Features

- [x] Collect location
- [x] Use on application in background
- [ ] Use on application in suppend

## Usage

### Start a LocationManager

```swift
import LLLocation
	let rule = Rule.init(with: [(loging: 5 , stoping: 5),(loging: 10 , stoping: 10)]);
	locationManager = LLLocationManager.init(rule: rule)
 	locationManager.useInBackgroundTask = true
	locationManager.saveLocationInShareModel = false
	locationManager.start()
        
	let model = LocationShareModel.shareModel
	model.locations.setAppendBlock { (location) in
		let location = location as! CLLocation
       //do something with location            
	}
```
		
        
