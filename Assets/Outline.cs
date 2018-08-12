using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class Outline : MonoBehaviour {
	#region public_variables
	[SerializeField] Color _backgroundColor = new Color(1, 1, 1, 0);
	[SerializeField] Color _lineColor = new Color(0, 0, 0, 1);
	[SerializeField, Range(0, 1)] float _colorSensitivity = 1f;
	[SerializeField, Range(0, 1)] float _normalSensitivity = 1f;
	[SerializeField, Range(0, 1)] float _depthSensitivity = 1f;
	[SerializeField, Range(0, 2)] float _lowerThreshold = 0.05f;
	[SerializeField, Range(0, 2)] float _upperThreshold = 1f;
	[SerializeField] FilterType _filter;
	[SerializeField] bool _canny;
	[SerializeField] Shader _shader;
	#endregion

	#region private_variables
	Material _material;
	#endregion

	void Start () {
		
	}
	
	void Update () {
		if(_depthSensitivity > 0 || _normalSensitivity > 0)
			GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if(_material == null)
		{
			_material = new Material(_shader);
			_material.hideFlags = HideFlags.DontSave;
		}

		_material.SetColor("_Background", _backgroundColor);
		_material.SetColor("_OutlineColor", _lineColor);
		_material.SetFloat("_ColorSensitivity", _colorSensitivity);
		_material.SetFloat("_NormalSensitivity", _normalSensitivity);
		_material.SetFloat("_DepthSensitivity", _depthSensitivity);
		_material.SetFloat("_Threshold", _lowerThreshold);
		_material.SetFloat("_InvRange", 1f/(_upperThreshold - _lowerThreshold));

		if(_filter == FilterType.Roberts)
		{
			_material.EnableKeyword("_ROBERTS_CROSS");
			_material.DisableKeyword("_PREWITT");
			_material.DisableKeyword("_SOBEL");
			_material.DisableKeyword("_KIRSCH");
		}

		if(_filter == FilterType.Prewitt)
		{
			_material.DisableKeyword("_ROBERTS_CROSS");
			_material.EnableKeyword("_PREWITT");
			_material.DisableKeyword("_SOBEL");
			_material.DisableKeyword("_KIRSCH");
		}

		if(_filter == FilterType.Sobel)
		{
			_material.DisableKeyword("_ROBERTS_CROSS");
			_material.DisableKeyword("_PREWITT");
			_material.EnableKeyword("_SOBEL");
			_material.DisableKeyword("_KIRSCH");
		}

		if(_filter == FilterType.Kirsch)
		{
			_material.DisableKeyword("_ROBERTS_CROSS");
			_material.DisableKeyword("_PREWITT");
			_material.DisableKeyword("_SOBEL");
			_material.EnableKeyword("_KIRSCH");
		}

		if(_canny)
		{
			_material.EnableKeyword("_CANNY");
			RenderTexture grab = new RenderTexture(src);
			Graphics.Blit(src, grab, _material, 0);
			_material.SetTexture("_GrabTex", grab);
		}
		else
			_material.DisableKeyword("_CANNY");

		Graphics.Blit(src, dest, _material, 1);
	}
}

public enum FilterType{
	Roberts,
	Prewitt,
	Sobel,
	Kirsch
}
