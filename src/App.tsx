import React from "react"
import {BrowserRouter as Router, Route, Switch} from "react-router-dom"
import {ApolloClient, ApolloProvider, InMemoryCache} from "@apollo/client"

import {Home} from "./Home"
import {Carbon} from "./Carbon"

const createApolloClient = () => {
    return new ApolloClient({
        cache: new InMemoryCache(),
        uri: "https://63sahjvltfatfii2yzjuj5jrjy.appsync-api.us-west-2.amazonaws.com/graphql",
        headers: {"x-api-key": ""},
    })
}

class App extends React.Component {
    render() {
        return (
            <ApolloProvider client={createApolloClient()}>
                <Router>
                    <Switch>
                        <Route exact path="/" component={Home}/>
                        <Route exact path="/carbon" component={Carbon}/>
                    </Switch>
                </Router>
            </ApolloProvider>
        )
    }
}

export default App
