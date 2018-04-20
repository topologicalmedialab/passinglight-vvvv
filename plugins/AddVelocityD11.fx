//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D  VTex <string uiname="Velocity";>;

SamplerState g_samLinear : IMMUTABLE
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
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tColor <string uiname="Color Transform";>;
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



float vFlowDims;
float fRadius;
float2 MousePos;
float2 LastMousePos;
int init;
float gaussian(float d2, float radius)
{
  return exp(-d2 / radius);
}

float4 PS(vs2ps In): SV_Target
{
    // MousePos.y = 1-MousePos.y;
	//LastMousePos.y = 1-LastMousePos.y;
	float3 mouseVector = vFlowDims * float3( ( MousePos.x - LastMousePos.x ), ( 1-MousePos.y) - (1-LastMousePos.y), 1 ); 
  	mouseVector = -max(-1., min(1., mouseVector));	
    float2 pos = float2(MousePos.x,1-MousePos.y) - In.TexCd.xy;
	float3 result = min(.8f,init * mouseVector.xyz * gaussian(dot(pos, pos), fRadius));
	
	return float4(result.xyz*1,gaussian(dot(pos, pos), fRadius));
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




