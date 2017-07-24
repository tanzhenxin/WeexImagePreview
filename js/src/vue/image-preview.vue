<template>
  <div>
    <slider class="slider" :index="index" @click="clickHandler">
      <div class="frame" v-for="image in images" >
        <image class="image" :src="image" resize="contain"></image>
      </div>
      <indicator class="indicator" :style="indicatorStyle"></indicator>
    </slider>
  </div>
</template>
<style>
  .slider {
    width: 750px;
    height: 100%;
  }

  .frame {
    width: 750px;
    height: 100%;
    overflow: scroll;
  }

  .image {
    width: 750px;
    height: 100%;
  }

  .indicator {
    height: 20px;
    bottom: 96px !important;
  }
</style>
<script>
  module.exports = {
    data () {
      return {
        images: [],
        index: 0,
        indicatorStyle: {
          itemColor: 'rgba(255, 195, 0, .5)',
          itemSelectedColor: '#ffc300',
          itemSize: '20px',
          bottom: '24px',
        }
      }
    },
    methods: {
      clickHandler () {
        this.$el.style.opacity = '0';
        setTimeout(() => {
          this.$el.remove();
        }, 300);
      }
    }
  }
</script>
