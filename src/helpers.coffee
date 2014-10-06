Zap.typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
Zap.valueExists = (value) -> value not in ["", null, undefined]
Zap.valueMissing = (value) -> value in ["", null, undefined]