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



float vFlowDims;
float dissipation;
float timestep;

float4 PS(vs2ps In): SV_Target
{
    float2 pos    =  In.TexCd.xy;
  	float4 v      = VTex.Sample(g_samLinear, pos); 
  	pos += timestep * v.xy / vFlowDims;
  	float4 newValue =  VTex.Sample(g_samLinear, pos);  
	newValue *= dissipation;	
	
	return newValue;
}





technique10 Constant
{
	pass P0
	{SetVertexShader( CompileShader( vs_4_0, VS() ) );
	 SetPixelShader( CompileShader( ps_4_0, PS() ) );
		//alphablendenable = false;    
	}
}




