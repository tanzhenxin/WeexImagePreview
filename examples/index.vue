<template>
	<div class="conatiner">
		<text style="margin-bottom: 20px;">weex plugin examples</text>
		<div @click="createAction" style="margin: 20px;padding:20px;background-color:#1ba1e2;color:#fff;"><text style="color:#fff">hello world</text></div>
	</div>
</template>

<style>
	.container{
		flex: 1;
	}
</style>

<script>

	// const plugin = weex.requireModule('weexPlguinDemo');
	const imagePreview = weex.requireModule('weexImagePreview');

	module.exports = {
		data: {
			value: '',
			index: 0,
			txtChange: ''
		},
		methods: {
			createAction: function() {
				// plugin.show();
				imagePreview.show({
					// 要浏览的图片路径
					images: [
						'http://gw2.alicdn.com/tfscom/tuitui/T1.4CbFrpcXXXXXXXX',
						'http://gw2.alicdn.com/tfscom/tuitui/T1_x9rFx0bXXXXXXXX',
						'http://gw1.alicdn.com/tfscom/tuitui/T1qCqmFyxbXXXXXXXX',
						'http://gw2.alicdn.com/tfscom/tuitui/T1iVipFq0aXXXXXXXX',
						'http://gw.alicdn.com/bao/uploaded/i2/T114R6FpxcXXXXXXXX_!!0-item_pic.jpg'
					],
					// 起始图片索引
					index: 2
				})
			}
		}
	}
</script>
