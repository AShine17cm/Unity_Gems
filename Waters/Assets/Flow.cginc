#if !defined(FLOW_INCLUDED)
#define FLOW_INCLUDED

sampler2D _FlowMap;

//�������  flow-vector, ����� jump( �����Ȩ����0��ʱ����һ��jump )
float3 FlowUVW_Jump(float2 uvIN,float2 jump,float tiling,float speed,float strength, bool flowB)
{
	float2 flowVector = tex2D(_FlowMap, uvIN).rg * 2 - 1;		//�ݶ�����
	flowVector *= strength;
	float noise = tex2D(_FlowMap, uvIN).a;						//shader������ �����Ż�Ϊһ������
	float time = _Time.y*speed + noise;                               //��ʱ��Ӧ����������ֹͬʱ���� fade

	float phaseOffset = flowB ? 0.5 : 0;				//��λƫ�ƣ����ڻ������ flow
	float progress = frac(time + phaseOffset);			//ʱ�� ѭ����
	float3 uvw;
	uvw.xy = uvIN - flowVector * progress;
	uvw.xy *= tiling;									//ƽ��
	uvw.xy += phaseOffset;
	uvw.xy += (time - progress) * jump;					//ֵtime-progress������ÿ����������ͼ�� ƫ��һС��
	uvw.z = 1 - abs(1 - 2 * progress);					//Ȩ�ص� ping-pong
	return uvw;
}

//�������  flow-vector
float3 FlowUVW(float2 uvIN,bool flowB)
{
	float2 flowVector = tex2D(_FlowMap, uvIN).rg * 2 - 1;		//�ݶ�����
	float noise = tex2D(_FlowMap, uvIN).a;						//shader������ �����Ż�Ϊһ������
	float time = _Time.y + noise;                               //��ʱ��Ӧ����������ֹͬʱ���� fade

	float phaseOffset = flowB ? 0.5 : 0;				//��λƫ�ƣ����ڻ������ flow
	float progress = frac(time + phaseOffset);			//ʱ�� ѭ����
	float3 uvw;
	uvw.xy = uvIN - flowVector * progress+phaseOffset;	//
	uvw.z = 1 - abs(1 - 2 * progress);					//Ȩ�ص� ping-pong
	return uvw;
}

//��ʱ��Ӧ�� ��Ƶ����
float3 FlowUVW_TimeNoise(float2 uvIN)
{
	float2 flowVector = tex2D(_FlowMap, uvIN).rg * 2 - 1;      //�ݶ�����
	float noise = tex2D(_FlowMap, uvIN).a;						//shader������ �����Ż�Ϊһ������
	float time = _Time.y + noise;                               //��ʱ��Ӧ����������ֹͬʱ���� fade

	float progress = frac(time);		//ʱ�� ѭ����
	float3 uvw;
	uvw.xy = uvIN - flowVector * progress;
	uvw.z = 1 - abs(1 - 2 * progress);	//Ȩ�ص� ping-pong
	return uvw;
}


#endif