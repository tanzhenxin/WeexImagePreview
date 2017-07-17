package org.weex.plugin.weeximagepreview;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ImageView;

import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;
import com.nostra13.universalimageloader.core.listener.SimpleImageLoadingListener;

import java.util.ArrayList;

public class ImagePreviewActivity extends Activity {
    private static final String TAG = "UIImagepreviewActivity";
    private ViewPager mPager;
    private ArrayList<String> imgs;
    private int index;
    private CircleIndicator mCircleIndicator;
    private float deviceScale;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.activity_image_preview);

        // ImageLoader配置参数
        ImageLoaderConfiguration mConfiguration = ImageLoaderConfiguration.createDefault(this);
        ImageLoader.getInstance().init(mConfiguration);

        deviceScale = (float)getScreenHeight(this) / (float)getScreenWidth(this);

        try {
            imgs = getIntent().getStringArrayListExtra("images");
            index = getIntent().getIntExtra("index", 0);
        } catch(Exception e) {
            e.printStackTrace();
            finish();
        }

        mPager = (ViewPager) findViewById(R.id.pager);
        mCircleIndicator = (CircleIndicator) findViewById(R.id.indicator);
        mPager.setPageMargin((int) (getResources().getDisplayMetrics().density * 15));
        mPager.setAdapter(new PagerAdapter() {
            @Override
            public int getCount() {
                return imgs.size();
            }

            @Override
            public boolean isViewFromObject(View view, Object object) {
                return view == object;
            }

            @Override
            public void destroyItem(ViewGroup container, int position, Object object) {
                container.removeView((View) object);
            }

            @Override
            public Object instantiateItem(ViewGroup container, int position) {
                final PhotoView photoView = new PhotoView(ImagePreviewActivity.this);
                photoView.enable();
                photoView.setScaleType(ImageView.ScaleType.FIT_CENTER);
                photoView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        finish();
                        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
                    }
                });
                ImageLoader.getInstance().loadImage(imgs.get(position), new SimpleImageLoadingListener(){
                    @Override
                    public void onLoadingComplete(String imageUri, View view, Bitmap loadedImage) {
                        float scale = (float) loadedImage.getHeight() / (float) loadedImage.getWidth();
                        if (scale > deviceScale) {
                            photoView.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
                        } else {
                            photoView.setScaleType(ImageView.ScaleType.FIT_CENTER);
                        }
                        photoView.setImageBitmap(loadedImage);
                    }
                });
                container.addView(photoView);
                return photoView;
            }
        });
        mPager.setCurrentItem(index);
        mCircleIndicator.setViewPager(mPager);
    }

    @Override
    public void onBackPressed() {
        finish();
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }

    private int getScreenWidth(Context context) {
        return context.getResources().getDisplayMetrics().widthPixels;
    }

    private int getScreenHeight(Context context) {
        return context.getResources().getDisplayMetrics().heightPixels;
    }
}
