package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;

	import away3d.animators.SkeletonAnimationSet;
	import away3d.animators.SkeletonAnimator;
	import away3d.animators.data.Skeleton;
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.core.pick.PickingType;
	import away3d.debug.AwayStats;
	import away3d.debug.Debug;
	import away3d.entities.Mesh;
	import away3d.entities.SegmentSet;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.lights.DirectionalLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.DAEParser;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.WireframeSphere;
	import away3d.utils.Cast;

	[SWF(backgroundColor = "#000000", width = "600", height = "400", frameRate = "30")]
	public class Intermediate_DAEAnimation extends Sprite
	{
		//signature swf
		[Embed(source = "/../embeds/signature.swf", symbol = "Signature")]
		public var SignatureSwf:Class;

		// astro boy
		[Embed(source = "/../embeds/astroboy_maya_fixed.dae", mimeType = "application/octet-stream")]
		public static var _dae_clazz:Class;

		// tableTexture
		[Embed(source = "/../embeds/floor_diffuse.jpg")]
		private var tableTex:Class;

		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var awayStats:AwayStats;
		private var cameraController:HoverController;

		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;

		//light objects
		private var light:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var direction:Vector3D;

		//material objects
		private var groundMaterial:TextureMaterial;

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 4;
		private var panSpeed:Number = 4;
		private var distanceSpeed:Number = 4;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;

		//animation variables
		private var _mesh:Mesh;
		private var _animator:SkeletonAnimator;
		private var _animationSet:SkeletonAnimationSet;
		private var _skeleton:Skeleton;
		private var _daeHolder:ObjectContainer3D;

		//debug variables
		private var _debugSegmentSets:Vector.<SegmentSet> = new Vector.<SegmentSet>;

		private var _time:int = 0;

		/**
		 * Constructor
		 */
		public function Intermediate_DAEAnimation()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initLights();
			initMaterials();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			view = new View3D();
			view.forceMouseMove = true;
			scene = view.scene;
			camera = view.camera;
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 45, 20, 700, -90);

			// Chose global picking method ( chose one ).
			view.mousePicker = PickingType.RAYCAST_BEST_HIT; // Uses the CPU, guarantees accuracy with a little performance cost.

			view.addSourceURL("srcview/index.html");
			addChild(view);

			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			addChild(SignatureBitmap);

			awayStats = new AwayStats(view);
			addChild(awayStats);
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			//setup the lights for the scene
			light = new DirectionalLight(1, -1, 1);
			light.ambient = 0.8;
			light.color = 0xffffff;

			lightPicker = new StaticLightPicker([light]);
			scene.addChild(light);
		}

		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			// create ground mesh
			groundMaterial = new TextureMaterial(Cast.bitmapTexture(tableTex));
			groundMaterial.shadowMethod = new FilteredShadowMapMethod(light);
			groundMaterial.lightPicker = lightPicker;
			groundMaterial.ambient = 0.5;
			groundMaterial.specular = 0.5;
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			var mesh:Mesh = new Mesh(new PlaneGeometry(5000, 5000), groundMaterial);
			mesh.mouseEnabled = true;
			view.scene.addChild(mesh);

			//debug purpose
			//Debug.active = true;

			// load DAE
			var context:AssetLoaderContext = new AssetLoaderContext();
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, loaded, false, 0, true);
			var loader:Loader3D = new Loader3D();
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, complete, false, 0, true);
			loader.loadData(new _dae_clazz(), context, null, new DAEParser());
		}

		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}

		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			// Update camera.
			if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;

				cameraController.panAngle += panIncrement;
				cameraController.tiltAngle += tiltIncrement;
				cameraController.distance += distanceIncrement;
			}


			var _debugSegmentSet:SegmentSet;
			for (var i:int = 0; i < _debugSegmentSets.length; i++)
			{
				_debugSegmentSet = _debugSegmentSets[i];
				_debugSegmentSet.transform = _animator.globalPose.jointPoses[i].toMatrix3D();
			}

			// Render 3D.
			view.render();
		}

		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
			awayStats.x = stage.stageWidth - awayStats.width;
		}

		/**
		 * capture while load events
		 * @param event
		 */
		private function loaded(event:AssetEvent):void
		{
			switch (event.asset.assetType)
			{
				case AssetType.CONTAINER:
				{
					_daeHolder = ObjectContainer3D(event.asset);
					_daeHolder.scale(20);
					_daeHolder.y = 132;
					break;
				}

				case AssetType.MATERIAL:
				{
					var material:TextureMaterial = event.asset as TextureMaterial;

					if (!material)
						break;

					material.lightPicker = lightPicker;
					material.ambient = 1;
					break;
				}

				case AssetType.SKELETON:
				{
					_skeleton = event.asset as Skeleton;
					break;
				}

				case AssetType.ANIMATION_SET:
				{
					_animationSet = event.asset as SkeletonAnimationSet;

					if (!_animator)
						_animator = new SkeletonAnimator(_animationSet, _skeleton);

					_mesh.animator = _animator;

					break;
				}

				case AssetType.MESH:
				{
					_mesh = event.asset as Mesh;
					break;
				}

				default:
				{
					break;
				}
			}
		}

		/**
		 * capture complete event
		 * @param event
		 */
		private function complete(event:LoaderEvent):void
		{
			Debug.active = false;

			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, loaded);
			event.target.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, complete);

			scene.addChild(_daeHolder);

			_animator.play("node_0");
			_animator.playbackSpeed = 1;
		}

		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
		}

		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;

			// for testing purpose
			//debugJoint();
		}

		//--------------------------------------------------------------------- DEBUG

		/**
		 * for debug purpose
		 */
		private function debugJoint():void
		{
			var _debugSegmentSet:SegmentSet;

			if (!_animator)
				return;

			var num:int = int(Math.random() * _animator.globalPose.jointPoses.length);

			if (_debugSegmentSets.length > 0)
				return;

			for (var i:int = 0; i < _animator.globalPose.jointPoses.length; i++)
			{
				_debugSegmentSet = new WireframeSphere(2, 4, 3, 0x336633, .25);
				_debugSegmentSets.push(_mesh.addChild(_debugSegmentSet));
			}
		}
	}
}
