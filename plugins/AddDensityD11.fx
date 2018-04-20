//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D  Tex <string uiname="InkTexture";>;

SamplerState sampV : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	


	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd: TEXCOORD0;
};

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
    Out.TexCd =  mul(input.TexCd, tTex);
    return Out;
}

float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };

float vFlowDims;
float fRadius;
float2 mouse;
float init;

float gaussian(float d2, float radius)
{
  return exp(-d2 / radius);
}
float4 PS(vs2ps In): SV_Target
{
   
    float2 pos = float2(mouse.x,1- mouse.y) - In.TexCd.xy;	
	//float4 tex = Tex.Sample(sampV, In.TexCd.xy);	tex.rgb *
	float3 result = min(.8f, init * cAmb.rgb *  gaussian(dot(pos, pos), fRadius));
	
	return float4(result.xyz,gaussian(dot(pos, pos), fRadius));
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
		//alphablendenable = false;    
	}
}




