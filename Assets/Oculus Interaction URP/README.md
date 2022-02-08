# URP Shaders for the Meta Interaction SDK

## What's the Interaction SDK?
Meta recently released a new experimental API for their SDK called the [Interaction SDK](https://developer.oculus.com/blog/presence-platform-interaction-sdk-and-tracked-keyboard-now-available/).
It provides several useful tools to enable hand tracking based interaction to your VR apps.

## So What's This, Then?
Currently, the SDK only supports Unity's Built-In Render Pipeline by default. For folks
who have made the jump to Unity's Universal Render Pipeline, by default most of the
objects will just show up in magenta.

I wanted to be able to use a lot of the tools and samples in my prototypes, so I took on
the effort of porting the custom shaders in the SDK to URP.

The package contains all of the updated shaders, copies of the materials that use the new
shaders, and copies of the sample scenes that point to the updated materials. I also
included a prefab variant of the sample interaction rig so you can just drop that into
your own work.

## How Do I Use It?
There are really two ways you could use this, importing into your existing URP project, or
creating a new project from scratch and working from there.

### Existing Projects
I am assuming you already have the following:
1. A project that includes Oculus SDK v37.
2. The project is configured to use URP instead of the built-in renderer.

From there, you should be able to download the latest released unitypackage, and import it
into your project. It will create a new folder in the top level of your Assets hierarchy
called "Interaction URP".

### New Projects
1. In Unity Hub, create a new URP project
2. Install Oculus SDK v37 - you can get this on the Asset Store or directly from Meta.
3. [Configure your project for VR](https://developer.oculus.com/documentation/unity/unity-gs-overview/).

Once you have a project that can build & deploy to your device, install the latest Interaction 
URP unitypackage.

### Bonus Usage Option
Technically, this repo is a preconfigured URP project with everything set up and ready to go,
so you could just clone it and open it in Unity if you want to just try it out.

## Final Project Configuration
If you haven't already, update your OculusProjectConfig to enable Hand Tracking with high frequency.

Also, there are two shaders that require the addition of custom layers and custom render features,
for adding the necessary stencil support for the window+skybox effect in the sample scenes.

If you haven't already modified your renderer & layers, running the included command 
*Assets > Interaction URP > Configure Project* should do everything for you. If you prefer
to make the changes by hand, the required changes are as follows:

### Layers
Layer 6: Stencil Mask
Layer 7: Stencil Vis

### Custom Render Features
Main Renderer Changes:
* Opaque Layer Mask: Remove the stencil layers (6 & 7)
 
Feature #1
* Name: Stencil Mask
* Event: BeforeRenderingOpaques
* Queue: Opaque
* Layer Mask: Stencil Mask (layer 6)
* Override Stencil: true
  * Value: 5
  * Compare Function: Always
  * Pass: Replace
  * Fail: Keep
  * Z Fail: Keep

Feature #2
* Name: Stencil Vis
* Event: BeforeRenderingOpaques
* Queue: Opaque
* Layer Mask: Stencil Vis (layer 7)
* Override Stencil: true
  * Value: 5
  * Compare Function: Equal
  * Pass: Keep
  * Fail: Keep
  * Z Fail: Keep

## FAQ's
* Is this done?
  * Nope, currently all of the sample scenes should run as expected, but there are more shaders to rewrite.
* Why did you duplicate the scenes like this?
  * I wanted this to have minimal impact on Oculus SDK installations, so if you decide to remove it, it won't have a negative impact on your project at large
* Can you make variants of more of the prefabs in the SDK?
  * Happy to -- please file an issue and I'll try to prioritize the most common requests
* You used ShaderGraph for some shaders and raw HLSL for others -- why?
  * A mix of "I'm learning as I go" and "Some shaders would be hard to impossible in ShaderGraph". I might move more of the ShaderGraph stuff to HLSL now that I feel more comfortable with it

## Questions? Issues?
Please feel free to file an issue for any changes you'd like to see - additional SDK shaders,
rendering errors, &c. I'll do my best to get them updated ASAP (also, PR's welcome!).

If you just want to say hi, you can find me on twitter [@rje](https://twitter.com/rje).