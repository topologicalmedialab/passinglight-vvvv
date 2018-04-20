//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D  FTex <string uiname="FlowTexture";>;

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
	
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
float scale;

float4 PS(vs2ps In): SV_Target
{
   float2 tc = In.TexCd.xy;
     if(tc.x <  1.0f/vFlowDims)
        tc.x += 1.0/vFlowDims;
     else if(tc.y < 1.0f/vFlowDims)
        tc.y += 1.0f/vFlowDims;
     else if(tc.x >  (vFlowDims - 1.0f)/vFlowDims)
        tc.x -= 1.f/vFlowDims.x;
     else if(tc.y >  (vFlowDims - 1.0f)/vFlowDims)
        tc.y -= 1.f/vFlowDims;
     else
        clip(-1.);     
	
	return scale * FTex.Sample(g_samLinear, tc);
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




