VIN BarcodeScanner
==================

Cross-platform VIN BarcodeScanner for Cordova / PhoneGap.

Follows the [Cordova Plugin spec](http://docs.phonegap.com/en/3.0.0/plugin_ref_spec.md.html), so that it works with [Plugman](https://github.com/apache/cordova-plugman).

This plugin leverages Cordova/PhoneGap's [require/define functionality used for plugins](http://simonmacdonald.blogspot.ca/2012/08/so-you-wanna-write-phonegap-200-android.html). 

Note: the Android source for this project includes an Android Library Project.
_plugman_ currently doesn't support Library Project refs, so its been
prebuilt as a jar library. Any updates to the Library Project should be
committed with an updated jar.

Note: the iOS source for this project includes a XCode Universal Static Library Project.
_plugman_ currently doesn't support Library Project refs, so its been
prebuilt as a fat library. Any updates to the Static Library Project should be
committed with an updated library file (.a). This library is being using if the devices does not run iOS7, otherwise it uses the new API for scanning barcodes (AVCaptureMetaDataOutput).

Note: the WP8 source does not include the ZXing.Net library, so it has to
be included during installation.

## Using the plugin ##
The plugin creates the object `plugins.barcodeScanner` with the method `scan(success, fail)`. 

**Only CODE_39 barcode types will be scanned, as this is optimized for VINs!**

## Installing the plugin ##

1. Download the repo using GIT or just a ZIP from Github.
2. Add the plugin to your project (from the root of your project):

```
   cordova plugin add <path_download_plugin>
```

Windows Phone 8 needs some more steps:

1. Open your project on Visual Studio 2012.
2. Right click on `References`, select `Magange NuGet Packages`.
3. Search online for `ZXing.Net` (created by Michael Jahn at http://zxingnet.codeplex.com).
4. Install it.

`success` and `fail` are callback functions. Success is passed an object with data, type and cancelled properties. Data is the text representation of the barcode data, type is the type of barcode detected and cancelled is whether or not the user cancelled the scan.

A full example could be:
```
   var scanner = cordova.require("com.phonegap.plugins.barcodescanner.barcodescanner");

   scanner.scan(
      function (result) {
          alert("We got a barcode\n" +
                "Result: " + result.text + "\n" +
                "Format: " + result.format + "\n" +
                "Cancelled: " + result.cancelled);
      }, 
      function (error) {
          alert("Scanning failed: " + error);
      }
   );
```

## Encoding a Barcode ##
The plugin creates the object `window.plugins.barcodeScanner` with the method `encode(type, data, success, fail)`. 
Supported encoding types:

* TEXT_TYPE
* EMAIL_TYPE
* PHONE_TYPE
* SMS_TYPE

```
A full example could be:

   var scanner = cordova.require("com.phonegap.plugins.barcodescanner.barcodescanner");

   scanner.encode(BarcodeScanner.Encode.TEXT_TYPE, "http://www.nytimes.com", function(success) {
  	        alert("encode success: " + success);
  	      }, function(fail) {
  	        alert("encoding failed: " + fail);
  	      }
  	    );
```

## Thanks on Github ##

So many -- check out the original [iOS](https://github.com/phonegap/phonegap-plugins/tree/master/iOS/BarcodeScanner) and [Android](https://github.com/phonegap/phonegap-plugins/tree/master/Android/BarcodeScanner) repos.


## Licence ##

The MIT License

Copyright (c) 2010 Matt Kane

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
