#if !defined(FLOW_INCLUDED)
#define FLOW_INCLUDED

sampler2D _FlowMap;

//混合两个  flow-vector, 并添加 jump( 当混合权重是0的时候，做一个jump )
float3 FlowUVW_Jump(float2 uvIN,float2 jump,float tiling,float speed,float strength, bool flowB)
{
	float2 flowVector = tex2D(_FlowMap, uvIN).rg * 2 - 1;		//梯度向量
	flowVector *= strength;
	float noise = tex2D(_FlowMap, uvIN).a;						//shader编译器 可以优化为一个采样
	float time = _Time.y*speed + noise;                               //对时间应用噪音，防止同时出现 fade

	float phaseOffset = flowB ? 0.5 : 0;				//相位偏移，用于混合两个 flow
	float progress = frac(time + phaseOffset);			//时间 循环段
	float3 uvw;
	uvw.xy = uvIN - flowVector * progress;
	uvw.xy *= tiling;									//平铺
	uvw.xy += phaseOffset;
	uvw.xy += (time - progress) * jump;					//值time-progress整数，每个周期在贴图上 偏移一小块
	uvw.z = 1 - abs(1 - 2 * progress);					//权重的 ping-pong
	return uvw;
}

//混合两个  flow-vector
float3 FlowUVW(float2 uvIN,bool flowB)
{
	float2 flowVector = tex2D(_FlowMap, uvIN).rg * 2 - 1;		//梯度向量
	float noise = tex2D(_FlowMap, uvIN).a;						//shader编译器 可以优化为一个采样
	float time = _Time.y + noise;                               //对时间应用噪音，防止同时出现 fade

	float phaseOffset = flowB ? 0.5 : 0;				//相位偏移，用于混合两个 flow
	float progress = frac(time + phaseOffset);			//时间 循环段
	float3 uvw;
	uvw.xy = uvIN - flowVector * progress+phaseOffset;	//
	uvw.z = 1 - abs(1 - 2 * progress);					//权重的 ping-pong
	return uvw;
}

//对时间应用 低频噪音
float3 FlowUVW_TimeNoise(float2 uvIN)
{
	float2 flowVector = tex2D(_FlowMap, uvIN).rg * 2 - 1;      //梯度向量
	float noise = tex2D(_FlowMap, uvIN).a;						//shader编译器 可以优化为一个采样
	float time = _Time.y + noise;                               //对时间应用噪音，防止同时出现 fade

	float progress = frac(time);		//时间 循环段
	float3 uvw;
	uvw.xy = uvIN - flowVector * progress;
	uvw.z = 1 - abs(1 - 2 * progress);	//权重的 ping-pong
	return uvw;
}


#endif