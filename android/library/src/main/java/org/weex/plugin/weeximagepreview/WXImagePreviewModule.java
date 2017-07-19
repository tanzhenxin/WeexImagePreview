package org.weex.plugin.weeximagepreview;

import android.app.Activity;
import android.content.Intent;
import android.widget.Toast;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.weex.plugin.annotation.WeexModule;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.taobao.weex.common.WXModule;

import org.json.JSONException;

import java.util.ArrayList;
import java.util.Map;
import java.util.Objects;

@WeexModule(name = "weexImagePreview")
public class WXImagePreviewModule extends WXModule {
    private int index = 0;
    private JSONArray images;
    
    @JSMethod
    public void show(Map<String, Object> options) {
        if (options.containsKey("index")) {
            index = (int) options.get("index");
        }

        if (options.containsKey("images")) {
            images = (JSONArray) options.get("images");
        }

        if (images != null && images.size() > 0) {
            ArrayList<String> imgs = new ArrayList<>();
            for (int i = 0; i < images.size(); i++) {
                imgs.add(images.getString(i));
            }

            if (index < 0 ) index = 0;
            if (index > imgs.size()) index = imgs.size() - 1;

            Intent intent = new Intent(mWXSDKInstance.getContext(), ImagePreviewActivity.class);
            intent.putExtra("index", index);
            intent.putStringArrayListExtra("images", imgs);
            mWXSDKInstance.getContext().startActivity(intent);
            ((Activity)mWXSDKInstance.getContext()).overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        } else {
            Toast.makeText(mWXSDKInstance.getContext(), "参数有误", Toast.LENGTH_SHORT).show();
        }
    }
}