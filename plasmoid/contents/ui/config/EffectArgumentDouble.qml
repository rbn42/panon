import QtQuick 2.0

EffectArgument{
    vali:DoubleValidator{
        top:{
            if(root.effect_arguments[index])
                if('max' in root.effect_arguments[index])
                    return root.effect_arguments[index].max;
            return 1000000;
        }
            
        bottom:{
            if(root.effect_arguments[index])
                if('min' in root.effect_arguments[index])
                    return root.effect_arguments[index].min;
            return -1000000;
        }
        notation:DoubleValidator.StandardNotation
    }
}
