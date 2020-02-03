#version 130

#define shrink_step $shrink_step

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float x=fragCoord.x/iResolution.x;
    if(fragCoord.y<1){
        fragColor= texture(iChannel1, vec2(x,0));
        return;
    }
    int step_=min(shrink_step ,int(iResolution.x /1.2 / iResolution.y));
    float current_width=(iResolution.x)-fragCoord.y*step_;
    float prev_width=(iResolution.x)-(fragCoord.y-1)*step_;

    x=(fragCoord.x- fragCoord.y*step_/2) / current_width;
    x=x * prev_width + (fragCoord.y-1)*step_/2;
    x=x/iResolution.x;
    if(x<0 || x>1){
        fragColor=vec4(0,0,0,0);
        return;
    }

    fragColor= texture(iChannel2, vec2(x,(fragCoord.y-1)/iResolution.y));
}
