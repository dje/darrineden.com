import React from 'react'
import {BrowserRouter as Router, Route, Switch} from 'react-router-dom'
import {Home, Carbon} from './Pages'

class App extends React.Component {
    render() {
        return (
            <Router>
                <div>
                    <Switch>
                        <Route exact path="/" component={Home}/>
                        <Route exact path="/carbon" component={Carbon}/>
                    </Switch>
                </div>
            </Router>
        )
    }
}

export default App
