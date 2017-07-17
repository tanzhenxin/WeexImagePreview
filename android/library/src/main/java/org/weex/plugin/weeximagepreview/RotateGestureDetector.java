package org.weex.plugin.weeximagepreview;

import android.view.MotionEvent;

/**
 * Created by Gavin on 2017/6/14 10:19.
 * huijian.xhj@alibaba-inc.com
 * https://github.com/bm-x/PhotoView/blob/master/library/src/main/java/com/bm/library/RotateGestureDetector.java
 */

public class RotateGestureDetector {
    private static final int MAX_DEGREES_STEP = 120;

    private OnRotateListener mListener;

    private float mPrevSlope;
    private float mCurrSlope;

    private float x1;
    private float y1;
    private float x2;
    private float y2;

    public RotateGestureDetector(OnRotateListener l) {
        mListener = l;
    }

    public void onTouchEvent(MotionEvent event) {

        final int Action = event.getActionMasked();

        switch (Action) {
            case MotionEvent.ACTION_POINTER_DOWN:
            case MotionEvent.ACTION_POINTER_UP:
                if (event.getPointerCount() == 2) mPrevSlope = caculateSlope(event);
                break;
            case MotionEvent.ACTION_MOVE:
                if (event.getPointerCount() > 1) {
                    mCurrSlope = caculateSlope(event);

                    double currDegrees = Math.toDegrees(Math.atan(mCurrSlope));
                    double prevDegrees = Math.toDegrees(Math.atan(mPrevSlope));

                    double deltaSlope = currDegrees - prevDegrees;

                    if (Math.abs(deltaSlope) <= MAX_DEGREES_STEP) {
                        mListener.onRotate((float) deltaSlope, (x2 + x1) / 2, (y2 + y1) / 2);
                    }
                    mPrevSlope = mCurrSlope;
                }
                break;
            default:
                break;
        }
    }

    private float caculateSlope(MotionEvent event) {
        x1 = event.getX(0);
        y1 = event.getY(0);
        x2 = event.getX(1);
        y2 = event.getY(1);
        return (y2 - y1) / (x2 - x1);
    }
}

interface OnRotateListener {
    void onRotate(float degrees, float focusX, float focusY);
}
