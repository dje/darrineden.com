import {CollectorExporter} from '@opentelemetry/exporter-collector';
import {DocumentLoad} from '@opentelemetry/plugin-document-load';
import {SimpleSpanProcessor} from '@opentelemetry/tracing';
import {UserInteractionPlugin} from '@opentelemetry/plugin-user-interaction';
import {WebTracerProvider} from '@opentelemetry/web';

const provider = new WebTracerProvider({
    plugins: [
        new DocumentLoad(),
        new UserInteractionPlugin()
    ]
});

provider.addSpanProcessor(new SimpleSpanProcessor(new CollectorExporter({
    url: 'https://api.darrineden.com/trace'
})));
