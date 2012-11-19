package
{
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	[SWF(width = "1024", height = "768", frameRate = "60", backgroundColor = "#000000")]
	public class Main extends Basic_LoadDAE_Animation
	{
		public function Main()
		{
			super();

			// support autoOrients
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
		}
	}
}

