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
    
    @JSMethod
    public void show(Map<String, Object> options) {
        int index = (int) options.get("index");
        JSONArray images = (JSONArray) options.get("images");

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
    }
}