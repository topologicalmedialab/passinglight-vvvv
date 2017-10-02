//@author: sanch
//@help: particle self collision
//@tags: particule
//@credits: dottore,vux
int samples;
float time;
bool reset;
float force;
float damp;
float radius;
float floorThreshold;

Texture2D tex <string uiname="Texture";>;
Texture2D texDepth <string uiname="Depth Texture";>;
Texture2D texNoise <string uiname="Noise Texture";>;

SamplerState mySampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

StructuredBuffer<float3> resetPos;

float3 drainPos;
float3 platePos;
float3 humanPos;

float aging;
int spawnFlag;

struct particle
{
	float3 pos;
	float3 vel;
	float3 age;
};

RWStructuredBuffer<particle> Output : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID )
{
	float PI = 3.14159265;
	
	int m = 8192;
	float id = (float)DTid.x / m;
	float timeWindow = 0.25;
	
	if (reset)
	{
		Output[DTid.x].vel = float3(0,0,0);
		if((time < id && id < time + timeWindow)
			|| (time < id + 1 && id + 1 < time + timeWindow)) {
			Output[DTid.x].pos = resetPos[DTid.x];
			Output[DTid.x].age = float3(0, 0, 0);
		}
		else {
			Output[DTid.x].pos = float3(100,100,0);
			Output[DTid.x].age = float3(2, 0, 0);
		}
	}
	else if(Output[DTid.x].age.x > 1) {
		if(spawnFlag > 0) {
			Output[DTid.x].vel = float3(0,0,0);
			if((time < id && id < time + timeWindow)
				|| (time < id + 1 && id + 1 < time + timeWindow)) {
				Output[DTid.x].pos = resetPos[DTid.x];
				Output[DTid.x].age = float3(0, 0, 0);
			}
			else {
				Output[DTid.x].pos = float3(100,100,0);
				Output[DTid.x].age = float3(2, 0, 0);
			}
		}
		else {
			Output[DTid.x].pos = float3(100,100,0);
		}
	}

	else
	{
	
	 	float3 p = Output[DTid.x].pos;
	    float3 v = Output[DTid.x].vel;
		float2 pNew ={0.0f,0.0f};
        float2 d_1n ={0.0f,0.0f};
		
		float depth = texDepth.SampleLevel(mySampler, (float2(p.x*0.5f,p.y*-0.5f) )+0.5f,0).r ;
		float isOnFloor = depth < floorThreshold;

	    for (int i =0; i<samples ;i++){

	        pNew.x = cos(((1.0f/samples)*i*2.0f*PI))*radius;
	        pNew.y = sin(((1.0f/samples)*i*2.0f*PI))*radius;

	    	if(isOnFloor) {
	        	//float d = texNoise.SampleLevel(mySampler, (float2((p.x + pNew.x)*0.5f,(p.y + pNew.y)*-0.5f) )+0.5f,0).r;
		    	//d_1n += 1*pNew * d;
	    	} else {
	        	d_1n += pNew * tex.SampleLevel(mySampler, (float2((p.x + pNew.x)*0.5f,(p.y + pNew.y)*-0.5f) )+0.5f,0).r;
		    	float d = texDepth.SampleLevel(mySampler, (float2((p.x + pNew.x)*0.5f,(p.y + pNew.y)*-0.5f) )+0.5f,0).r;
		    	float dcoeff = 100;
		        d_1n += pNew * d * dcoeff;
	    	}
	    	
        }
		float3 fieldsAdd = float3(d_1n * float2(force * 1.0f,force * 1.0f),0);
		
		// drain
		if(isOnFloor) {
			float3 drainVel = drainPos - Output[DTid.x].pos;
			float3 humanVel = humanPos - Output[DTid.x].pos;
			float drainLen = length(drainVel);
			float humanLen = length(humanVel);
			if(drainLen < humanLen) {
				drainVel /= drainLen;
				drainVel *= 0.00003f;
				drainVel.y *= 0.5;
				fieldsAdd = drainVel;
				Output[DTid.x].age.x += 0.00001;
			} else {
				humanVel /= humanLen;
				humanVel *= 0.0001f;
				humanVel.y *= 0.5;
				fieldsAdd = humanVel;
				Output[DTid.x].age.x += 0.00001;
			}

			float3 plateVel = platePos - Output[DTid.x].pos;
			float pv = length(plateVel * float3(1, 9.0/16.0, 0));
			if(pv < 0.5) {
				plateVel /= pv;
				plateVel *= -0.00005f;
				plateVel.y *= 0.5;
				fieldsAdd += plateVel;
			}
		}
		Output[DTid.x].vel *= damp;
    	Output[DTid.x].vel += fieldsAdd * float3(1, 16.0/9.0, 0);
        Output[DTid.x].pos += Output[DTid.x].vel;

		if(length(Output[DTid.x].pos.xy - drainPos.xy) < 0.03f) {
			Output[DTid.x].age.x += aging;
		}
		
		if(Output[DTid.x].age.x > 1) {
			Output[DTid.x].pos = float3(100,100,0);
		}

		//Output[DTid.x].pos.z = 0;
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
