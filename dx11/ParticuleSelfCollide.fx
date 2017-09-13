//@author: sanch
//@help: particle self collision
//@tags: particule
//@credits: dottore,vux
int samples;
bool reset;
float force;
float damp;
float radius;
float floorThreshold;

Texture2D tex <string uiname="Texture";>;
Texture2D texDepth <string uiname="Depth Texture";>;

SamplerState mySampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

StructuredBuffer<float3> resetPos;

float3 drainPos;

struct particle
{
	float3 pos;
	float3 vel;
	
};

RWStructuredBuffer<particle> Output : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID )
{
	float PI = 3.14159265;
	if (reset)
	{
		Output[DTid.x].pos = resetPos[DTid.x];
		Output[DTid.x].vel = 0;
		
	}
	
	else
	{
	
	 	float3 p = Output[DTid.x].pos;
	    float3 v = Output[DTid.x].vel;
		float2 pNew ={0.0f,0.0f};
        float2 d_1n ={0.0f,0.0f};
		
        float2 d_2n ={0.0f,0.0f};
		
		float depth = texDepth.SampleLevel(mySampler,  (float2(p.x*0.5f,p.y*-0.5f) )+0.5f,0).r ;

	    for (int i =0; i<samples ;i++){

	        pNew.x = cos(((1.0f/samples)*i*2.0f*PI))*radius;
	        pNew.y = sin(((1.0f/samples)*i*2.0f*PI))*radius;
		
	        d_1n +=  pNew * tex.SampleLevel(mySampler,  (float2((p.x + pNew.x)*0.5f,(p.y + pNew.y)*-0.5f) )+0.5f,0).r ;
	    	
	    	float d = texDepth.SampleLevel(mySampler,  (float2((p.x + pNew.x)*0.5f,(p.y + pNew.y)*-0.5f) )+0.5f,0).r;
	    	if(d > floorThreshold)
		        d_2n += pNew * d;
        }
		d_1n += d_2n;
		float isOnFloor = depth < floorThreshold;
		float3 fieldsAdd = float3(d_1n * float2(force*  1.0f,force * 1.0f),0);
		if(isOnFloor) {
			float3 drainVel = drainPos - Output[DTid.x].pos;
			drainVel /= length(drainVel);
			drainVel *= 0.0001f;
			fieldsAdd = drainVel;
			//fieldsAdd += drainVel;
		}
		Output[DTid.x].vel *= damp;
    	Output[DTid.x].vel += fieldsAdd;
        Output[DTid.x].pos += Output[DTid.x].vel;
	}
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 simulation
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSConstantForce() ) );
	}
}
